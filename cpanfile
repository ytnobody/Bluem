requires 'perl', '5.008001';
requires 'Bloom::Filter';
requires 'Module::Load';

on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'File::Temp';
    requires 'HTTP::Request::Common';
};

